defmodule OpenPublishing.Object do
  @moduledoc false
  
  import OpenPublishing.Resource.Implementation

  object Document do
    aspect ":minimal" do
      field :GUID
      field :id
      
      field :title
      field :subtitle
      field :status

      field :grin_url
      field :mobile_url
    end

    aspect ":basic" do
      field :realm_id
      field :user_id

      field :language_id

      field :current_price
      field :authors
      field :product_form
    end

    aspect "abstract.*" do
      field :abstract
    end

    aspect "search_tags.*" do
      field :search_tags
    end

    aspect "ebook.*" do
      field :ebook
    end

    aspect "identifiers.*" do
      field :identifiers
    end
  end

  object Author do
    aspect ":basic" do
      field :GUID
      field :id
      field :first_name
      field :last_name
      field :grin_url
    end
  end

  object OrderNormalized do
    aspect "*" do
      field :realm_id
      field :transactions
      field :account
    end
  end

  object OrderFulfillment do
    aspect "*" do
      field :status
      field :shippings
      field :external_supplier_references
    end
  end
end
