module Physique
  class MetadataConfig
    def initialize
      @metadata = default_metadata

      Albacore.subscribe :build_version do |data|
        @metadata.version  = data.nuget_version
      end
    end

    def with_metadata
      yield @metadata
    end

    private

    def default_metadata
      metadata = Albacore::NugetModel::Metadata.new
      metadata.description = 'MISSING'
      metadata.authors = 'MISSING'
      metadata
    end
  end
end