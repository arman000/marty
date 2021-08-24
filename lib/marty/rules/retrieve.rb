module Marty
  module Rules
    class Retrieve
      def self.package_list(host, port, api_key)
        path = "/packages?api_key=#{api_key}"

        Marty::RpcCall.json_call(
          host, port, path, {}, false, {}, true)
      end

      def self.download(host, port, api_key, package_name, starts_at_raw)
        starts_at = Time.zone.parse(starts_at_raw.to_s).iso8601
        path = "/packages/#{package_name}?api_key=#{api_key}&starts_at=#{starts_at}"
        resp = Marty::RpcCall.json_call(host, port, path, {}, false, {}, true)
        return if resp['builds'].blank?

        resp['builds'].each do |build|
          starts_at = build['starts_at']
          script = build['script']
          meta = build['metadata']

          build_name = build['name']
          next if Marty::Rules::Package.find_by(
            name: package_name,
            starts_at: starts_at
          )

          Marty::Rules::Package.create!(
            name: package_name,
            build_name: build_name,
            starts_at: starts_at,
            script: script,
            metadata: meta
          )
        end
      end
    end
  end
end
