FactoryBot.define do
  sequence(:random_float) { BigDecimal("#{rand(200)}.#{rand(99)}") }

  factory :base_variant, class: Spree::Variant do
    price           { 19.99 }
    cost_price      { 17.00 }
    sku             { generate(:sku) }
    weight          { generate(:random_float) }
    height          { generate(:random_float) }
    width           { generate(:random_float) }
    depth           { generate(:random_float) }
    is_master       { 0 }
    track_inventory { true }

    product       { |p| p.association(:base_product, stores: [Spree::Store.default]) }
    option_values { [create(:option_value)] }

    # ensure stock item will be created for this variant
    before(:create) { create(:stock_location) unless Spree::StockLocation.any? }

    after(:create) do |variant|
      Spree::StockLocation.all.each do |stock_location|
        next if stock_location.stock_item(variant).present?

        stock_location.propagate_variant(variant)
      end
    end

    factory :variant do
      # on_hand 5
      product { |p| p.association(:product, stores: [Spree::Store.default]) }

      factory :with_image_variant do
        images { create_list(:image, 1) }
      end
    end

    factory :master_variant do
      is_master { 1 }
    end

    factory :on_demand_variant do
      track_inventory { false }

      factory :on_demand_master_variant do
        is_master { 1 }
      end
    end
  end
end
