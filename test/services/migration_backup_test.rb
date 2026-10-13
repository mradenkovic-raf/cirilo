require "test_helper"
require "open3"
require "tmpdir"
require "fileutils"

class MigrationBackupTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir("migration-backup-", Rails.root.join("tmp"))
    @path = File.join(@directory, "production.sqlite3")
    @versions = Dir[Rails.root.join("db/migrate/[0-9]*_*.rb")].map { |path| File.basename(path).split("_", 2).first }.sort
    @destination = File.join(@directory, "migration-backups", "production.sqlite3-before-#{@versions.last}.sqlite3")
  end

  teardown { FileUtils.remove_entry(@directory) }

  test "pending v20 and v21 migrations back up committed WAL data and never overwrite the snapshot" do
    with_database(@versions.reject { |version| version.start_with?("20261013") }) do |database|
      database.execute("PRAGMA journal_mode=WAL")
      database.execute("INSERT INTO learners VALUES (1, 321)")
      assert File.exist?("#{@path}-wal"), "The backup must include a live WAL database"
      output, error, status = run_hook
      assert status.success?, error
      assert_includes output, "verified and saved"
      SQLite3::Database.new(@destination, readonly: true) do |backup|
        assert_equal [[1, 321]], backup.execute("SELECT * FROM learners")
        assert_equal [["ok"]], backup.execute("PRAGMA integrity_check")
        assert_equal @versions.length - 2, backup.get_first_value("SELECT count(*) FROM schema_migrations")
      end
      assert_equal 0o600, File.stat(@destination).mode & 0o777
      assert_equal 0o700, File.stat(File.dirname(@destination)).mode & 0o777
      original = File.binread(@destination)
      database.execute("UPDATE learners SET xp=654")
      assert run_hook.last.success?
      assert_equal original, File.binread(@destination)
      assert_empty Dir[File.join(File.dirname(@destination), ".pending-*")]
      assert_equal 654, database.get_first_value("SELECT xp FROM learners")
    end
  end

  test "fresh databases and fully migrated databases need no snapshot" do
    assert run_hook.last.success?
    refute File.exist?(@path)
    with_database(@versions) { assert run_hook.last.success? }
    refute Dir.exist?(File.dirname(@destination))
  end

  test "invalid source database blocks startup before migration" do
    File.write(@path, "not a database")
    _, error, status = run_hook
    refute status.success?
    assert_includes error, "Startup stopped before migrations"
    refute File.exist?(@destination)
  end

  test "unavailable backup directory blocks startup" do
    with_database(@versions.first(10)) do
      File.write(File.dirname(@destination), "unavailable")
      _, error, status = run_hook
      refute status.success?
      assert_includes error, "Startup stopped before migrations"
    end
  end

  test "corrupt existing destination is never overwritten and blocks startup" do
    with_database(@versions.first(10)) do
      Dir.mkdir(File.dirname(@destination))
      File.write(@destination, "damaged backup")
      _, error, status = run_hook
      refute status.success?
      assert_includes error, "Startup stopped before migrations"
      assert_equal "damaged backup", File.read(@destination)
    end
  end

  private

  def with_database(versions)
    SQLite3::Database.new(@path) do |database|
      database.execute("CREATE TABLE schema_migrations (version varchar NOT NULL PRIMARY KEY)")
      versions.each { |version| database.execute("INSERT INTO schema_migrations VALUES (?)", version) }
      database.execute("CREATE TABLE learners (id integer PRIMARY KEY, xp integer NOT NULL)")
      yield database
    end
  end

  def run_hook
    Open3.capture3({ "DATABASE_PATH" => @path }, RbConfig.ruby, "-rbundler/setup", Rails.root.join("bin/backup-before-migrate").to_s)
  end
end
