class HomeController < ApplicationController
  RAIL_SIZE = 4

  def show
    @categories = nav_categories.sort_by(&:name)
    @category_covers = Product.with_photo.includes(:category).where(category: @categories)
      .select("DISTINCT ON (category_id) products.*").order(:category_id, :id).index_by(&:category_id)

    @deals = todays_deals
    @deals_end_at = Time.current.end_of_day
    @popular = Product.popular.includes(:category).limit(8).to_a
    @recommended, @recommended_personal = recommended_products
    @recently_viewed = recently_viewed_products
    @hero_products = hero_products
    @promo_categories = @categories.index_by(&:slug)
    @max_discounts = Product.on_sale.group(:category_id)
      .maximum(Arel.sql("ROUND((compare_at_price_cents - price_cents) * 100.0 / compare_at_price_cents)"))

    load_card_state(@deals + @popular + @recommended + @recently_viewed)
  end

  private

  # Three top-rated photos from different categories. Books are left out:
  # cover art with printed titles fights the headline.
  def hero_products
    Product.with_photo.includes(:category).where.not(category: Category.where(slug: "books"))
      .top_rated.limit(30).to_a.uniq(&:category_id).first(3)
  end

  # The deal rail is the same for everyone all day and changes at midnight,
  # so the countdown on the page tells the truth.
  def todays_deals
    Product.on_sale.in_stock.includes(:category).to_a
      .shuffle(random: Random.new(Date.current.jd)).first(RAIL_SIZE)
  end

  # Signed in with orders: top rated products from the categories they buy
  # from that they haven't bought yet. Otherwise: top rated overall.
  def recommended_products
    if current_user
      purchased = OrderItem.joins(:order).where(orders: { user_id: current_user.id })
      category_ids = Product.where(id: purchased.select(:product_id)).distinct.pluck(:category_id)

      if category_ids.any?
        picks = Product.includes(:category).where(category_id: category_ids)
          .where.not(id: purchased.select(:product_id)).in_stock.top_rated.limit(RAIL_SIZE).to_a
        return [ picks, true ] if picks.any?
      end
    end

    [ Product.includes(:category).in_stock.top_rated.limit(RAIL_SIZE).to_a, false ]
  end
end
