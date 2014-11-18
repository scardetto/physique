FEED_URL = 'https://www.nuget.org'
SYMBOLS_FEED_URL = 'http://nuget.gw.symbolsource.org/Public/NuGet'

describe Physique::PublishNugetsConfig do
  let(:config) { Physique::PublishNugetsConfig.new }
  let(:opts) { config.opts }

  describe 'when setting feed data directly' do
    let(:first_feed) { opts.feeds[0] }

    it 'should create a default feed and delegate its configuration' do
      config.feed_url = FEED_URL
      config.symbols_feed_url = SYMBOLS_FEED_URL

      opts.feeds.count.should eq(1)

      first_feed.name.should eq('default')
      first_feed.feed_url.should eq(FEED_URL)
      first_feed.symbols_feed_url.should eq(SYMBOLS_FEED_URL)
      first_feed.gen_symbols.should be_true
    end
  end
end

describe Physique::PublishNugetsFeedConfig do
  let(:config) { Physique::PublishNugetsFeedConfig.new }
  let(:feed) { config.opts }

  it 'should set opts values' do
    config.name = 'default'
    config.feed_url = FEED_URL
    config.symbols_feed_url = SYMBOLS_FEED_URL
    config.api_key = 'API_KEY'

    feed.name.should eq('default')
    feed.feed_url.should eq(FEED_URL)
    feed.symbols_feed_url.should eq(SYMBOLS_FEED_URL)
    feed.gen_symbols.should be_true
  end
end
