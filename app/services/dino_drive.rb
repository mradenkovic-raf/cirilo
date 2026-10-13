class DinoDrive
  class InvalidRun < StandardError; end

  DURATION_MS = 24_000
  MAX_HITS = 3
  STARTING_LANE = 1
  MIN_MOVE_MS = 120

  def self.state(run)
    {
      status: run&.status || "ready", token: run&.token,
      duration_ms: DURATION_MS, starting_lane: STARTING_LANE, max_hits: MAX_HITS,
      obstacles: run&.obstacles || [], hits: run&.hits || 0,
      elapsed_ms: run&.elapsed_ms || 0, shield_earned: run&.shield_earned? || false
    }
  end

  def initialize(practice_session)
    @session = practice_session
  end

  def start!
    with_mission_lock do
      run = @session.road_run
      next run if run&.resolved?
      require_checkpoint!
      next run if run

      # One rock at a time, two clear lanes and at least 1.8 seconds to react.
      # Every lane occurs several times, so staying still cannot win the drive.
      lanes = 4.times.flat_map { [0, 1, 2].shuffle }.first(11)
      obstacles = lanes.each_with_index.map { |lane, i| { "at_ms" => 3500 + i * 1800, "lane" => lane } }
      @session.create_road_run!(token: SecureRandom.hex(24), obstacles: obstacles, started_at: Time.current)
    end
  end

  def skip!
    with_mission_lock do
      run = @session.road_run
      next run if run&.resolved?
      require_checkpoint!
      run ||= @session.build_road_run(token: SecureRandom.hex(24))
      run.update!(status: "skipped", finished_at: Time.current)
      run
    end
  end

  def finish!(token:, moves:, elapsed_ms:)
    with_mission_lock do
      run = @session.road_run
      unless run && token.is_a?(String) && ActiveSupport::SecurityUtils.secure_compare(run.token, token)
        raise InvalidRun, "Вожња се променила. Отвори је поново."
      end
      next run if run.resolved?
      require_checkpoint!
      validate_moves!(moves, elapsed_ms)
      if !run.started_at || (Time.current - run.started_at) * 1000 + 100 < elapsed_ms
        raise InvalidRun, "Вожња још траје. Стигни до циља."
      end

      result = self.class.evaluate(run.obstacles, moves, elapsed_ms)
      unless result[:hits] == MAX_HITS || elapsed_ms == DURATION_MS
        raise InvalidRun, "Стигни до циља или настави мисију без штита."
      end
      run.update!(status: result[:hits] == MAX_HITS ? "lost" : "won",
        moves: moves, hits: result[:hits], elapsed_ms: result[:elapsed_ms], finished_at: Time.current)
      run
    end
  end

  # Match dino_drive_engine.js: a move at the rock's timestamp takes effect
  # before that rock is evaluated. The third hit ends the drive immediately.
  def self.evaluate(obstacles, moves, elapsed_ms)
    lane = STARTING_LANE
    move_index = 0
    hits = 0
    obstacles.each do |rock|
      break if rock.fetch("at_ms") > elapsed_ms
      while moves[move_index] && moves[move_index].fetch("at_ms") <= rock.fetch("at_ms")
        lane = moves[move_index].fetch("lane")
        move_index += 1
      end
      next unless lane == rock.fetch("lane")
      hits += 1
      return { hits: hits, elapsed_ms: rock.fetch("at_ms") } if hits == MAX_HITS
    end
    { hits: hits, elapsed_ms: elapsed_ms }
  end

  private

  def with_mission_lock
    @session.learner.with_lock do
      @session.reload
      yield
    end
  end

  def require_checkpoint!
    raise InvalidRun, "Вожња те чека на половини мисије." unless @session.drive_checkpoint?
  end

  def validate_moves!(moves, elapsed_ms)
    valid = elapsed_ms.is_a?(Integer) && elapsed_ms.between?(0, DURATION_MS) &&
      moves.is_a?(Array) && moves.length <= 201
    raise InvalidRun, "Вожња није сачувана. Покушај поново." unless valid

    lane = STARTING_LANE
    previous_time = nil
    moves.each do |move|
      valid_move = move.is_a?(Hash) && move.keys.sort == %w[at_ms lane] &&
        move["at_ms"].is_a?(Integer) && move["at_ms"].between?(0, elapsed_ms) &&
        move["lane"].is_a?(Integer) && move["lane"].between?(0, 2) && (move["lane"] - lane).abs == 1 &&
        (previous_time.nil? || move["at_ms"] - previous_time >= MIN_MOVE_MS)
      raise InvalidRun, "Потези нису сачувани. Отвори вожњу поново." unless valid_move
      lane = move["lane"]
      previous_time = move["at_ms"]
    end
  end
end
