require "qcloud/sms/version"
require 'securerandom'
require 'digest'
require 'typhoeus'
require 'json'

module Qcloud
  module Sms
    class Configuration
      attr_accessor :app_id, :app_key, :sign
      def initialize
        @app_id = ''
        @app_key = ''
        @sign = ''
      end
    end

    class << self
      attr_writer :configuration

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def create_params(mobile, templId, params, random_number)
        sms_params = {
          "ext" => "",
          "extend" => "",
          "params" => params,
          "sig" => sig(mobile, random_number),
          "sign" => configuration.sign,
          "tel" => {
            "mobile" => mobile,
            "nationcode" => "86"
          },
          "time" => timestamp,
          "tpl_id" => templId
        }
        sms_params.to_json
      end

      def create_bunch_params(mobile, templId, params, random_number)
        tels = []
        mobile.each do |m|
          tels << {
            "mobile" => m,
            "nationcode" => "86"
          }
        end

        sms_params = {
          "ext" => "",
          "extend" => "",
          "params" => params,
          "sig" => sig(mobile, random_number),
          "sign" => configuration.sign,
          "tel" => tels,
          "time" => timestamp,
          "tpl_id" => templId
        }
        sms_params.to_json
      end

      def single_sender(mobile, templId, params)
        random_number = random
        Typhoeus.post("https://yun.tim.qq.com/v5/tlssmssvr/sendsms?sdkappid=" + configuration.app_id + "&random=" + random_number,
          headers: { "Content-Type": "application/json" },
          body: create_params(mobile, templId, params, random_number)
        )
      end

      def bunch_sender(mobile, templId, params)
        random_number = random
        Typhoeus.post("https://yun.tim.qq.com/v5/tlssmssvr/sendmultisms2?sdkappid=" + configuration.app_id + "&random=" + random_number,
          headers: { "Content-Type": "application/json" },
          body: create_bunch_params(mobile, templId, params, random_number)
        )
      end

      # 生成数字签名
      def sig(mobile, random_number)
        signature = "appkey=" + configuration.app_key + "&random=" + random_number + "&time=" + timestamp.to_s + "&mobile=" + mobile
        Digest::SHA256.hexdigest signature
      end

      # 生成随机数
      def random
        SecureRandom.random_number.to_s.slice(-10..-1)
      end

      # 生成短信时间戳
      def timestamp
        Time.now.to_i
      end

    end
  end
end
