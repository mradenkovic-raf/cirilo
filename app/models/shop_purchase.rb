class ShopPurchase < ApplicationRecord
  belongs_to :learner

  validates :item_key, presence: true, uniqueness: { scope: :learner_id }
  validates :price_paid, numericality: { only_integer: true, greater_than: 0 }
  validate :catalog_price_on_purchase, on: :create

  private

  def catalog_price_on_purchase
    item = ShopCatalog.find(item_key)
    unless item && item.fetch("price").positive? && item.fetch("price") == price_paid
      errors.add(:item_key, "мора бити понуда са важећом ценом")
    end
  end
end
