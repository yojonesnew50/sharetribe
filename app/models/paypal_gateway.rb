require 'paypal-sdk-adaptivepayments'

class PaypalGateway

  def initialize
    PayPal::SDK.configure(
      :mode      => "sandbox",  # Set "live" for production
      :app_id    => "APP-80W284485P519543T",
      :username  => "jb-us-seller_api1.paypal.com",
      :password  => "WX4WTU3S8MY44S7F",
      :signature => "AFcWxV21C7fd0v3bYYYRCpSSRl31A7yDhhsPUU2XhtMoZXsWHFxu-RWy" )
    @api = PayPal::SDK::AdaptivePayments.new
  end

  #send payment to the marketplace

  def pay(amount, seller_paypal_account)

    # Build request object
    @pay = @api.build_pay({
      :actionType => "PAY_PRIMARY",
      :cancelUrl => "https://warmshopping.com",
      :currencyCode => "USD",
      :feesPayer => "PRIMARYRECEIVER",
      :ipnNotificationUrl => "https://warmshopping.com/paypal/ipn_notify?paykey=${paykey}",
      :receiverList => {
        :receiver => [
          {
            :amount => (amount).to_i,
            :email => "warmshoppingpersonal+market@gmail.com", #MARKETPLACE ACCOUNT
            :primary => true
          },
          {
            :amount => (amount).to_i - ((amount) * 0.1).to_i,
            :email => seller_paypal_account, #SELLER ACCOUNT
          }
        ]
      },
      :returnUrl => "https://warmshopping.com" })

    # Make API call & get response
    @response = @api.pay(@pay)

    # Access response
    if @response.success? && @response.payment_exec_status != "ERROR"
      @response.payKey
    else
      @response.error[0].message
    end
  end


  #send payment to the seller get the key with the parameter
  def execute_payment(payKey)
    @execute_payment = @api.build_execute_payment({
      :payKey => payKey
    })

    # Make API call & get response
    @execute_payment_response = @api.execute_payment(@execute_payment)

    # Access Response
    if @execute_payment_response.success?
      @execute_payment_response.paymentExecStatus
      @execute_payment_response.payErrorList
      @execute_payment_response.postPaymentDisclosureList
    else
      @execute_payment_response.error
    end
  end

  def request_permissions
    @api = PayPal::SDK::Permissions::API.new

    # Build request object
    @request_permissions = @api.build_request_permissions({
      :scope => ["ACCESS_BASIC_PERSONAL_DATA","ACCESS_ADVANCED_PERSONAL_DATA", "REFUND", "DIRECT_PAYMENT"],
      :callback => "http://wamshopping.com/paypal/connect_callback" })

    # Make API call & get response
    @response = @api.request_permissions(@request_permissions)

    # Access Response
    if @response.success?
      @response.token
      @api.grant_permission_url(@response) # Redirect url to grant permissions
    else
      @response.error
    end
  end

  def get_basic_personal_data(token, verifier)

    p "TOKEN ==== #{token}"
    p "VERIFIER ==== #{verifier}"
    api = PayPal::SDK::Permissions::API.new

    # Build request object
    get_access_token = api.build_get_access_token({ :token => token, :verifier => verifier })

    # Make API call & get response
    get_access_token_response = api.get_access_token(get_access_token)

    p get_access_token_response
    # Access Response
    if get_access_token_response.success?
      api = PayPal::SDK::Permissions::API.new({
         :token => get_access_token_response.token, :token_secret => get_access_token_response.tokenSecret })

      paypal_response = api.get_basic_personal_data({
      :attributeList => {
        :attribute => [ "http://axschema.org/contact/email" ] } })

      return paypal_response.response
    else
      p ("ERROR WHEN GETTING BASIC PERSONAL DATA ======== #{get_access_token_response.error}")
      return false
    end

  end

  def refund(payKey)
    # Build request object
    transaction = Transaction.where(paypal_paykey: payKey).last

    p "transaction ==== #{transaction.seller}"
    @refund = @api.build_refund({
      :currencyCode => "BRL",
      :payKey => payKey,
      :email => transaction.seller.paypal_account
    })

    # Make API call & get response
    @refund_response = @api.refund(@refund)

    # Access Response
    if @refund_response.success?
      @refund_response.currencyCode
      @refund_response.refundInfoList
    else
      @refund_response.error
    end
  end

  def get_payment_details(txn_id)
    # Build request object
    @payment_details = @api.build_payment_details({
      :transactionId => txn_id 
    })

    # Make API call & get response
    @payment_details_response = @api.payment_details(@payment_details)

    # Access Response
    if @payment_details_response.success?
      return @payment_details_response
    else
      @payment_details_response.error
    end 
  end

end