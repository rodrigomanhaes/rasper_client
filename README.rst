rasper_client
=============

Ruby client to `rasper_server <https://github.com/rodrigomanhaes/rasper_server>`_.


Installation
------------

Add this line to your application's Gemfile::

    gem 'rasper_client'

And then execute::

    $ bundle

Or install it yourself as::

    $ gem install rasper_client


Usage
-----

Create a rasper client object, giving host and port::


    client = RasperClient::Client.new(host: 'host', port: 3000)


Having a client, you can add a report to server, passing a name, JRXML report
file content and, optionally, the images to be embedded in the report::

    client.add(name: 'programmers', content: 'content of JRXML',
      images: [{ name: 'image1.jpg', content: 'content of image1' },
               { name: 'image2.jpg', content: 'content of image2' }])


With the report uploaded, it's possible generate PDF reports::

    client.generate(name: 'programmers',
      data: [
        { name: 'Linus', software: 'Linux' },
        { name: 'Yukihiro', software: 'Ruby' },
        { name: 'Guido', software: 'Python' }
      ],
      parameters: { 'DATE' => 'January 12, 2013' })


The keys for ``data``'s inner hashes are report-specific. The parameters' keys
are report-specific, and are mandatory if report has parameters with no default
values.


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
