require "sqlite3"
require "fileutils"
require "time"

module Velora
  # Receipt ledger only. Receiving an event does not fulfill or confirm a booking.
  class EventStore
    def initialize(path)
      raise ArgumentError, "Persistent event database path required" if path.to_s.empty? || path == ":memory:"
      @path = path
      FileUtils.mkdir_p(File.dirname(path), mode: 0o700)
      with_database do |db|
        db.execute("PRAGMA journal_mode=WAL")
        db.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS stripe_event_receipts (
            event_id TEXT NOT NULL,
            account_scope TEXT NOT NULL,
            event_type TEXT NOT NULL,
            object_id TEXT NOT NULL,
            observation TEXT NOT NULL,
            amount INTEGER,
            currency TEXT,
            received_at TEXT NOT NULL,
            PRIMARY KEY (event_id, account_scope)
          )
        SQL
      end
    end

    def record(event, observation)
      object = event.fetch("data").fetch("object")
      amount = case event["type"]
               when "payment_intent.succeeded" then object["amount_received"]
               else object["amount_total"]
               end
      with_database do |db|
        db.execute(<<~SQL, [event.fetch("id"), event["account"] || "platform", event.fetch("type"), object.fetch("id"), observation, amount, object["currency"], Time.now.utc.iso8601])
          INSERT INTO stripe_event_receipts
          (event_id, account_scope, event_type, object_id, observation, amount, currency, received_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(event_id, account_scope) DO NOTHING
        SQL
        db.changes == 1
      end
    end

    private

    def with_database
      db = SQLite3::Database.new(@path)
      db.busy_timeout = 2000
      yield db
    ensure
      db&.close
    end
  end
end
