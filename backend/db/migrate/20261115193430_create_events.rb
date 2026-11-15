class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :source, null: false
      t.string :external_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :url, null: false
      t.string :language, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.datetime :submissions_starts_at
      t.datetime :submissions_ends_at
      t.boolean :submissions_open, null: false, default: false
      t.boolean :onsite, null: false, default: false
      t.string :location
      t.string :country
      t.string :twitch_url
      t.string :discord_url
      t.string :youtube_url
      t.jsonb :schedule
      t.datetime :synced_at, null: false

      t.timestamps
    end

    add_index :events, [ :source, :external_id ], unique: true
    add_index :events, :ends_at
  end
end
