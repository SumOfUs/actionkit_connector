require 'spec_helper'

describe ActionKitConnector::REST::User do
  describe '#update_user' do

    let(:params) {{
        akid: '8244194',
        email: 'totallynewemail@example.com',
        first_name: 'testy',
        last_name: 'test',
        country: 'United States',
        city: 'San Francisco',
        postal: '94103',
        address1: 'Jam Factory 123',
        address2: 'Random address'
    }}

    let(:duplicate_email_params) {{
        akid: '8244194',
        email: 'test@example.com',
        first_name: 'testy',
        last_name: 'test',
        country: 'United States',
        city: 'San Francisco',
        postal: '94103',
        address1: 'Jam Factory 123',
        address2: 'Random address'
    }}

    context 'with valid parameters' do
      it 'updates the user on ActionKit and returns no content' do
        VCR.use_cassette('rest_user_success') do
          resp = client.update_user(params[:akid], params)
          expect(resp.response.class).to eq Net::HTTPNoContent
          expect(resp.response.code.to_i).to eq 204
        end
      end
    end

    context 'with an email that already exists' do
      it 'gets back errors and has a conflict status' do
        VCR.use_cassette('rest_user_duplicate_email') do
          resp = client.update_user(duplicate_email_params[:akid], duplicate_email_params)
          expect(resp.response.code.to_i).to eq 409
          expect(resp["errors"]).to include({"email"=>["Conflict on unique key 'email' for value 'test@example.com'"]})
        end
      end
    end
  end

  describe "#filter_user_orders_by" do
    context 'with an email that already exists' do
      it 'gets back all the orders associated with the user email' do
        VCR.use_cassette('rest_user_filter_user_orders_by_email') do
          resp = client.filter_user_orders_by(field: "user__email", value: 'test@example.com')
          expect(resp.response.code.to_i).to eq 200
          expect(resp.parsed_response["objects"].size).to eql 20
          expect(resp.parsed_response["meta"]["total_count"]).to eql 35
        end
      end

      it 'should return 0 records' do
        VCR.use_cassette('rest_user_filter_user_orders_by_email_with_0_donations') do
          resp = client.filter_user_orders_by(field: "user__email", value: 'test1@example.com')
          expect(resp.response.code.to_i).to eq 200
          expect(resp.parsed_response["objects"].size).to eql 0
          expect(resp.parsed_response["meta"]["total_count"]).to eql 0
        end
      end
    end

    context 'with non existing user' do
      it 'gets back all the orders associated with the user email' do
        VCR.use_cassette('rest_user_filter_user_orders_by_email') do
          resp = client.filter_user_orders_by(field: "user__email", value: 'test@example.com')
          expect(resp.response.code.to_i).to eq 200
          expect(resp.parsed_response["objects"].size).to eql 20
          expect(resp.parsed_response["meta"]["total_count"]).to eql 35
        end
      end

      it 'should return 0 records' do
        VCR.use_cassette('rest_user_filter_user_orders_by_email_with_0_donations') do
          resp = client.filter_user_orders_by(field: "user__email", value: 'test1@example.com')
          expect(resp.response.code.to_i).to eq 200
          expect(resp.parsed_response["objects"].size).to eql 0
          expect(resp.parsed_response["meta"]["total_count"]).to eql 0
        end
      end
    end
  end
end



