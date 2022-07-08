class AddAppIdToAppPackage < ActiveRecord::Migration[7.0]
  def change
    add_reference :app_packages, :app, null: true, foreign_key: true
  end
end
