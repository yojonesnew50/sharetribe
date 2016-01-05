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

    p "ACCOUNT ===== #{seller_paypal_account}"


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