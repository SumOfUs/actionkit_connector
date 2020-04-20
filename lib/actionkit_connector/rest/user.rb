module ActionKitConnector
  module REST
    module User
      def update_user(id, data)
        self.class.put("/user/#{id}/", prep_options(data))
      end

      def filter_user_orders_by(field: 'user__email', value: '')
        return [] if field.to_s.empty? || value.to_s.empty?
        self.class.get("/order/?#{field}=#{value}", prep_options({}))
      end
    end
  end
end
