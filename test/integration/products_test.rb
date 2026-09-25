require "test_helper"

class ProductsTest < ActionDispatch::IntegrationTest
  test "index renders for a guest" do
    get products_path

    assert_response :success
    assert_select "a[href=?]", product_path(products(:headphones))
    assert_select "a[href=?]", product_path(products(:novel))
  end

  test "category filter only lists products in that category" do
    get products_path(category: categories(:books).slug)

    assert_response :success
    assert_select "a[href=?]", product_path(products(:novel))
    assert_select "a[href=?]", product_path(products(:headphones)), count: 0
  end

  test "search only lists matching products" do
    get products_path(query: "headphones")

    assert_response :success
    assert_select "a[href=?]", product_path(products(:headphones))
    assert_select "a[href=?]", product_path(products(:novel)), count: 0
  end

  test "an out-of-range page redirects to the last page" do
    get products_path(page: 999)

    assert_redirected_to products_path(page: 1)
  end

  test "an out-of-range page keeps the category filter when redirecting" do
    get products_path(category: "books", page: 999)

    assert_redirected_to products_path(category: "books", page: 1)
  end

  %w[garbage 0 -3 2abc].each do |page|
    test "a non-positive-integer page param #{page.inspect} redirects to the first page" do
      get products_path(page: page)

      assert_redirected_to products_path
    end
  end

  test "an invalid page param keeps the category and query when redirecting" do
    get products_path(category: "books", query: "novel", page: "garbage")

    assert_redirected_to products_path(category: "books", query: "novel")
  end

  test "a valid page that exists renders" do
    now = Time.current
    Product.insert_all(Array.new(ProductsController::PER_PAGE) do |i|
      { name: "Filler #{i}", description: "Pagination filler.", price_cents: 100, stock: 1,
        category_id: categories(:books).id, created_at: now, updated_at: now }
    end)

    get products_path(page: 2)

    assert_response :success
  end

  test "show renders" do
    get product_path(products(:headphones))

    assert_response :success
  end

  test "show for a missing product is a 404" do
    get product_path(id: 0)

    assert_response :not_found
  end
end
