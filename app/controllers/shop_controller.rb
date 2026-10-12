class ShopController < ApplicationController
  before_action :load_learner

  def index
    @items = ShopCatalog.items
    @purchases = @learner.shop_purchases.index_by(&:item_key)
  end

  def create
    result = ShopService.new(@learner).purchase!(item_id: params[:item_id], generation: params[:shop_generation] || "")
    if result.fetch(:purchased)
      flash[:shop_unlock] = result.fetch(:item).fetch("id")
      redirect_to category_path, notice: "Откључано! Твој нови изглед је спреман.", status: :see_other
    else
      redirect_to category_path, notice: "Овај изглед је већ твој. Можеш да га изабереш кад год пожелиш.", status: :see_other
    end
  rescue ShopService::Error => error
    redirect_to category_path, alert: error.message, status: :see_other
  end

  def equip
    ShopService.new(@learner).equip!(item_id: params[:item_id], generation: params[:shop_generation] || "")
    redirect_to category_path, notice: "Твој нови изглед је укључен!", status: :see_other
  rescue ShopService::Error => error
    redirect_to category_path, alert: error.message, status: :see_other
  end

  def reset
    ShopReset.reset!(@learner, confirmation: params[:confirm_reset], reset_word: params[:reset_word],
      generation: params[:shop_generation])
    redirect_to progress_path, notice: "XP и куповине су враћени на почетак. Слова, мисије и освојени делови су сачувани.", status: :see_other
  rescue ShopReset::InvalidRequest => error
    redirect_to progress_path, alert: error.message, status: :see_other
  end

  private

  def category_path
    item = ShopCatalog.find(params[:item_id])
    item ? shop_path(anchor: "shop-#{item.fetch('category')}") : shop_path
  end

  def load_learner
    @learner = current_learner
  end
end
