require 'spec_helper'

class FakesController < ApplicationController
  include Spree::Core::ControllerHelpers::Store
  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::Currency
  include Spree::Core::ControllerHelpers::Locale
end

describe Spree::Core::ControllerHelpers::Order, type: :controller do
  controller(FakesController) {}

  let(:user) { create(:user) }
  let(:order) { create(:order, user: user, store: store) }
  let!(:store) { Spree::Store.default }

  describe '#simple_current_order' do
    before { allow(controller).to receive_messages(try_spree_current_user: user) }

    it 'returns an empty order' do
      expect(controller.simple_current_order.item_count).to eq 0
    end
    it 'returns Spree::Order instance' do
      allow(controller).to receive_messages(cookies: double(signed: { token: order.token }))
      expect(controller.simple_current_order).to eq order
    end
  end

  describe '#current_order' do
    before do
      allow(controller).to receive_messages(current_store: store)
      allow(controller).to receive_messages(try_spree_current_user: user)
    end

    context 'create_order_if_necessary option is false' do
      let!(:order) { create :order, user: user, store: store }

      it 'returns current order' do
        expect(controller.current_order).to eq order
      end
    end

    context 'create_order_if_necessary option is true' do
      it 'creates new order' do
        expect do
          controller.current_order(create_order_if_necessary: true)
        end.to change(Spree::Order, :count).to(1)
      end

      it 'assigns the current_store id' do
        controller.current_order(create_order_if_necessary: true)
        expect(Spree::Order.last.store_id).to eq store.id
      end
    end

    context 'gets using the token' do
      let!(:order)       { create :order, user: user, store: store }
      let!(:guest_order) { create :order, user: nil, email: nil, token: 'token', store: store }

      before do
        expect(controller).to receive(:current_order_params).and_return(
          currency: store.default_currency, token: 'token', store_id: guest_order.store_id, user_id: user.id
        )
      end

      specify 'without the guest token being bound to any user yet' do
        expect(controller.current_order).to eq guest_order
      end
    end
  end

  describe '#associate_user' do
    before do
      allow(controller).to receive_messages(current_order: order, try_spree_current_user: user)
    end

    context "user's email is blank" do
      let(:user) { create(:user, email: '') }

      it 'calls Spree::Order#associate_user! method' do
        expect_any_instance_of(Spree::Order).to receive(:associate_user!)
        controller.associate_user
      end
    end

    context "user isn't blank" do
      it 'does not calls Spree::Order#associate_user! method' do
        expect_any_instance_of(Spree::Order).not_to receive(:associate_user!)
        controller.associate_user
      end
    end
  end

  describe '#set_current_order' do
    before { allow(controller).to receive_messages(try_spree_current_user: user) }

    context 'user has some incomplete orders other than current one' do
      before do
        allow(controller).to receive_messages(current_order: order, last_incomplete_order: incomplete_order, cookies: double(signed: { token: 'token' }))
      end

      context 'within the same store' do
        let!(:incomplete_order) { create(:order, user: user, store: order.store) }

        it 'calls Spree::Order#merge!' do
          expect(order).to receive(:merge!).with(incomplete_order, user)
          controller.set_current_order
        end
      end

      context 'within different store' do
        let!(:incomplete_order) { create(:order, user: user, store: create(:store)) }

        it 'does not call Spree::Order#merge!' do
          expect(order).not_to receive(:merge!)
          controller.set_current_order
        end
      end
    end

    context 'user has no incomplete orders other than current one' do
      it 'does not call Spree::Order#merge!' do
        expect(order).not_to receive(:merge!)
        controller.set_current_order
      end
    end
  end

  describe '#current_currency' do
    it 'returns current currency' do
      expect(controller.current_currency).to eq 'USD'
    end
  end

  describe '#ip_address' do
    it 'returns remote ip' do
      expect(controller.ip_address).to eq request.remote_ip
    end
  end
end
