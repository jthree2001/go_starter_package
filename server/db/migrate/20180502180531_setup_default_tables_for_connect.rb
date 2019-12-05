class SetupDefaultTablesForConnect < ActiveRecord::Migration[5.0]
  def change
  	create_table "sessions", force: :cascade do |t|
	    t.string   "session_id", null: false
	    t.text     "data"
	    t.timestamps
	    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
	    t.index ["updated_at"], name: "index_sessions_on_updated_at", using: :btree
 	end
  end
end
