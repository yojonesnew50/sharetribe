class PaypalAdaptivePaymentsController < ApplicationController

	def pay
		gateway = PaypalGateway.new
		p "sending payment"
		p gateway.pay

		render text: " ok"
	end
end