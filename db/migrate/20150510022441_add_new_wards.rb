class AddNewWards < ActiveRecord::Migration
  def change
  	Ward.create(:name => "Outside Toronto")
  	Ward.create(:name => "Etobicoke North")
  end
end
 