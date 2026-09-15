class AddImageKeywordToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :image_keyword, :string
  end
end
