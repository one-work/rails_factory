module Factory
  class In::PaymentsController < In::BaseController
    before_action :set_payment, only: [:wxpay_pc_pay]

    def index
    end

    def new
    end

    def create
      @payment = Trade::Payment.new(organ_id: params[:organ_id], type: params[:type])
      @payment.seller_identifier = current_wechat_app&.appid

      orders = current_organ.organ_orders.where(organ_id: params[:organ_id]).unpaid
      @payment.total_amount = orders.sum(:amount)

      orders.each do |order|
        @payment.payment_orders.build(order_id: order.id, check_amount: order.unreceived_amount)
      end

      @payment.save
    end

    # https://pay.weixin.qq.com/wiki/doc/api/native.php?chapter=6_5
    # 二维码有效期为2小时
    def wxpay_pc_pay
      @wxpay_order = @payment.native_order(current_wechat_app)

      if @wxpay_order['code'].present? || @wxpay_order.blank?
        render 'wxpay_pay_err', status: :unprocessable_entity
      else
        @image_url = QrcodeUtil.data_url @wxpay_order['code_url']
        render 'wxpay_pc_pay'
      end
    end

    private
    def set_payment
      @payment = Trade::Payment.find params[:id]
    end

  end
end
