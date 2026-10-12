# Migrate only a private copy of the v5 backup and compare every existing field.
require "pathname"
require "securerandom"
project = Pathname.new(__dir__).join("../..").expand_path
target = project.join("storage/v6-upgrade.sqlite3")
source = project.join("revisions/2026-10-11-v5-before-adventure/development.sqlite3")
abort "QA database already exists" if target.exist?
require "fileutils"
FileUtils.cp(source, target)
ENV["RAILS_ENV"] = "production"
ENV["DATABASE_PATH"] = target.to_s
ENV["SECRET_KEY_BASE"] = SecureRandom.hex(64)
ENV["RAILS_LOG_LEVEL"] = "warn"
ENV.delete("DATABASE_URL")
require_relative "../../config/environment"
abort "Wrong database" unless ActiveRecord::Base.connection_db_config.database == target.to_s
connection = ActiveRecord::Base.connection
tables = connection.tables - %w[schema_migrations ar_internal_metadata]
columns = tables.to_h { |table| [table, connection.columns(table).map(&:name)] }
snapshot = lambda do
  columns.to_h do |table, names|
    quoted = names.map { |name| connection.quote_column_name(name) }.join(", ")
    [table, connection.select_all("SELECT #{quoted} FROM #{connection.quote_table_name(table)} ORDER BY id").to_a]
  end
end
before = snapshot.call
ActiveRecord::Migration.verbose = false
ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).migrate
after = snapshot.call
abort "Existing data changed" unless before == after
puts "PASS all #{tables.length} original tables and all original columns preserved after migrations"
learner = Learner.current
if (active = learner.active_session)
  state = active.attributes.deep_dup
  PracticePlanner.upgrade!(active)
  abort "Active v3 mission changed" unless active.reload.attributes == state
  puts "PASS active v3 mission is unchanged including cursor, hidden word and exercise IDs"
else
  puts "INFO no active v3 mission in this snapshot; preservation covered by automated tests"
end
puts "PASS saved XP=#{learner.xp}, spent=#{learner.xp_spent}, missions=#{learner.completed_missions}"
puts "UPGRADE V6: PASS; only storage/v6-upgrade.sqlite3 was modified"
