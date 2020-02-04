module ActionKitConnector
  module REST
    module Order
      def get_order(id)
        self.class.get("/order/#{id}/", prep_options({}))
      end

      def update_order(id, data)
        self.class.patch("/order/#{id}/", prep_options(data))
      end
    end
  end
end
