require "rails_helper"

RSpec.describe BillsController, type: :controller do
  describe "#update_bill_shares (private)" do
    let(:bill_shares_relation) { instance_double("BillSharesRelation") }

    let(:bill) do
      instance_double(
        "Bill",
        id: 1,
        member_id: 10,
        total_amount: 100.0,
        bill_shares: bill_shares_relation
      )
    end

    let(:where_relation) { instance_double("WhereRelation") }
    let(:not_relation)   { instance_double("NotRelation") }

    before do
      allow(Bill).to receive(:transaction).and_yield
      allow(bill_shares_relation).to receive(:reload).and_return(bill_shares_relation)
    end

    context "when split_mode is equal (non-manual)" do
      it "splits total_amount equally and skips the payer, marking new shares as unpaid" do
        selected_member_ids = [10, 20, 30]
        split_mode = "equal"

        allow(bill_shares_relation).to receive(:where).and_return(where_relation)
        allow(where_relation).to receive(:not).and_return(not_relation)
        allow(not_relation).to receive(:destroy_all)

        share_20 = instance_double("BillShare", bill_id: 1, member_id: 20)
        share_30 = instance_double("BillShare", bill_id: 1, member_id: 30)

        expect(BillShare).to receive(:find_or_initialize_by)
          .with(bill_id: bill.id, member_id: 20)
          .and_return(share_20)

        expect(BillShare).to receive(:find_or_initialize_by)
          .with(bill_id: bill.id, member_id: 30)
          .and_return(share_30)

        [share_20, share_30].each do |share|
          allow(share).to receive(:amount=)
          allow(share).to receive(:status=)
          allow(share).to receive(:new_record?).and_return(true)
          allow(share).to receive(:save!)
        end

        controller.send(
          :update_bill_shares,
          bill,
          selected_member_ids,
          {},
          split_mode
        )

        equal_amount = (100.0 / 3).round(2)

        expect(share_20).to have_received(:amount=).with(equal_amount)
        expect(share_30).to have_received(:amount=).with(equal_amount)

        [share_20, share_30].each do |share|
          expect(share).to have_received(:status=).with("unpaid")
          expect(share).to have_received(:save!)
        end
      end
    end

    context "when split_mode is manual" do
      it "assigns manual amounts to each selected share" do
        selected_member_ids = [20, 30]
        split_mode = "manual"
        manual_amounts = { "20" => "12.5", "30" => "7.5" }

        allow(bill_shares_relation).to receive(:where).and_return(where_relation)
        allow(where_relation).to receive(:not).and_return(not_relation)
        allow(not_relation).to receive(:destroy_all)

        share_20 = instance_double("BillShare", bill_id: 1, member_id: 20)
        share_30 = instance_double("BillShare", bill_id: 1, member_id: 30)

        expect(BillShare).to receive(:find_or_initialize_by)
          .with(bill_id: bill.id, member_id: 20)
          .and_return(share_20)

        expect(BillShare).to receive(:find_or_initialize_by)
          .with(bill_id: bill.id, member_id: 30)
          .and_return(share_30)

        [share_20, share_30].each do |share|
          allow(share).to receive(:amount=)
          allow(share).to receive(:status=)
          allow(share).to receive(:new_record?).and_return(false)
          allow(share).to receive(:save!)
        end

        controller.send(
          :update_bill_shares,
          bill,
          selected_member_ids,
          manual_amounts,
          split_mode
        )

        expect(share_20).to have_received(:amount=).with(12.5)
        expect(share_30).to have_received(:amount=).with(7.5)
        expect(share_20).not_to have_received(:status=).with("unpaid")
        expect(share_30).not_to have_received(:status=).with("unpaid")
        expect(share_20).to have_received(:save!)
        expect(share_30).to have_received(:save!)
      end
    end

    context "when deselecting existing shares" do
      it "destroys shares not included in selected_member_ids" do
        selected_member_ids = [20]
        split_mode = "equal"

        expect(bill_shares_relation).to receive(:where).and_return(where_relation)
        expect(where_relation).to receive(:not).with(member_id: [20]).and_return(not_relation)
        expect(not_relation).to receive(:destroy_all)

        dummy_share = instance_double("BillShare", new_record?: true, bill_id: 1, member_id: 20)
        allow(dummy_share).to receive(:amount=)
        allow(dummy_share).to receive(:status=)
        allow(dummy_share).to receive(:save!)

        allow(BillShare).to receive(:find_or_initialize_by).and_return(dummy_share)

        controller.send(
          :update_bill_shares,
          bill,
          selected_member_ids,
          {},
          split_mode
        )
      end
    end
  end
end
