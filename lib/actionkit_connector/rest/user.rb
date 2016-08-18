module ActionKitConnector
  module REST
    module User

      def create_user(data)
        self.class.post('/user/', prep_options(data))
      end
    end
  end
end
