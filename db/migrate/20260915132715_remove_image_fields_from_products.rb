class RemoveImageFieldsFromProducts < ActiveRecord::Migration[8.1]
  def change
    # Product images are now always a generated colored tile (category color +
    # icon + name), computed on the fly -- no external photo URL or search
    # keyword to store anymore.
    remove_column :products, :image_url, :string
    remove_column :products, :image_keyword, :string
  end
end
