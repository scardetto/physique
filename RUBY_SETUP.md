# Installing Ruby on Windows

* The [Chocolatey Package Manager](http://chocolatey.org/) makes installing Ruby a breeze.  Think of it as NuGet for your machine.  To install it, follow the instructions on [their website](http://chocolatey.org/).

* Certain Chocolatey packages might not work with older versions of Powershell so update it to the latest version.

    ```
    $ choco install powershell
    ```

* Install Ruby.

    ```
    $ choco install ruby
    ```

* Restart your shell to refresh the environment variables.

* After restarting, check that ruby is installed by running the following. Note that your version may be slightly different:

    ```
    $ ruby --version
    ruby 2.1.5p273 (2014-11-13 revision 48405) [x64-mingw32]
    ```
    
* Install Ruby DevKit.

    ```
    $ choco install ruby2.devkit
    ```

* Register Ruby with DevKit.

    ```
    $ cd \tools\DevKit2
    $ echo - C:/tools/ruby215 >> config.yml
    $ ruby dk.rb install --force
    ```

You should now be ready to Ruby!
