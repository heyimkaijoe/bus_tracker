class CreateBusTrackingNotifs < ActiveRecord::Migration[7.1]
  def change
    create_table :bus_tracking_notifs do |t|
      t.string :phone
      t.string :route
      t.boolean :route_dir
      t.integer :target_stop

      t.timestamps
    end
  end
end
