class ShopService
  class Error < StandardError; end
  class InvalidItem < Error; end
  class InsufficientFunds < Error; end
  class NotOwned < Error; end
  class MissingRequirement < Error; end
  class StaleRequest < Error; end

  def self.current_generation?(learner, value)
    valid = (value.is_a?(Integer) && value.positive?) ||
      (value.is_a?(String) && value.match?(/\A[1-9]\d{0,8}\z/))
    valid && value.to_i == learner.shop_generation
  end

  def initialize(learner)
    @learner = learner
  end

  def purchase!(item_id:, generation: nil)
    item = catalog_item!(item_id)
    @learner.with_lock do
      verify_generation!(generation) unless generation.nil?
      if item.fetch("price").zero?
        select!(item)
        next { item: item, purchased: false }
      end

      # Retrying a purchase must not charge again or replace a later selection.
      if @learner.shop_purchases.exists?(item_key: item.fetch("id"))
        next { item: item, purchased: false }
      end
      requirement = @learner.shop_requirement(item)
      if requirement
        raise MissingRequirement, "Прво откључај: #{requirement.fetch('name')}."
      end
      if @learner.xp_balance < item.fetch("price")
        raise InsufficientFunds, "Треба ти још #{item.fetch('price') - @learner.xp_balance} енергије. Заврши мисију па се врати!"
      end

      @learner.shop_purchases.create!(item_key: item.fetch("id"), price_paid: item.fetch("price"))
      @learner.xp_spent += item.fetch("price")
      select!(item)
      { item: item, purchased: true }
    end
  end

  def equip!(item_id:, generation: nil)
    item = catalog_item!(item_id)
    @learner.with_lock do
      verify_generation!(generation) unless generation.nil?
      unless @learner.owns_shop_item?(item)
        raise NotOwned, "Прво откључај овај изглед у продавници."
      end
      select!(item)
      item
    end
  end

  private

  def verify_generation!(generation)
    unless self.class.current_generation?(@learner, generation)
      raise StaleRequest, "Продавница је враћена на почетак. Отвори је поново пре избора."
    end
  end

  def catalog_item!(item_id)
    ShopCatalog.find(item_id) || raise(InvalidItem, "Ова понуда не постоји. Изабери нешто из продавнице.")
  end

  def select!(item)
    @learner[ShopCatalog.selection_attribute(item)] = item.fetch("value")
    @learner.save!
  end
end
