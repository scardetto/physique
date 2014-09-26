describe Physique::PublishNugetsConfig do
  let(:config) { Physique::PublishNugetsConfig.new }
  let(:opts) { config.opts }

  describe 'when setting feed data directly' do
    let(:first_feed) { opts.feeds[0] }

    it 'should create a default feed and delegate its configuration' do
      config.feed_url = 'https://www.nuget.org'
      config.symbols_feed_url = 'http://nuget.gw.symbolsource.org/Public/NuGet'

      opts.feeds.count.should eq(1)

      first_feed.name.should eq('default')
      first_feed.feed_url.should eq('https://www.nuget.org')
      first_feed.symbols_feed_url.should eq('http://nuget.gw.symbolsource.org/Public/NuGet')
      first_feed.gen_symbols.should be_true
    end
  end
end

describe Physique::PublishNugetsFeedConfig do
  let(:config) { Physique::PublishNugetsFeedConfig.new }
  let(:feed) { config.opts }

  it 'should set opts values' do
    config.name = 'default'
    config.feed_url = 'https://www.nuget.org'
    config.symbols_feed_url = 'http://nuget.gw.symbolsource.org/Public/NuGet'
    config.api_key = 'API_KEY'

    feed.name.should eq('default')
    feed.feed_url.should eq('https://www.nuget.org')
    feed.symbols_feed_url.should eq('http://nuget.gw.symbolsource.org/Public/NuGet')
    feed.gen_symbols.should be_true
  end
end
