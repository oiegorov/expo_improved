# Expo
Expo helps you to run the experiments on Grid5000.

With Expo you can easily:

* reserve nodes;
* deploy environments;
* do whatever you want with the reserved nodes;

To run the simplest experiments it will be sufficient just to understand
the examples presented below. However, in order to happily use all the
Expo functionality you are recommended to have at least basic knowledge
of Grid5000 API and such tools as OAR, Kadeploy and Taktuk. 

## Installation

You can work with Expo in two modes:

1. On the frontend.
2. On your local machine. However, the Expo server should be started on
the frontend and SSH tunnel should be established (explained below).

In both cases the first thing to do:

    $ git clone git://github.com/oiegorov/expo_improved.git

Then

    $ export RUBYLIB=your_path/expo_improved/lib

### Run Expo exclusively on the frontend

    $ echo "base_uri: https://api.grid5000.fr/2.0/grid5000" > ~/.restfully/api.grid5000.fr.yml

And you are ready to go:

    $ your_path/expo_improved/bin/expo.rb path_to_your_test_file

### Run Expo from your local machine 

You have to configure both your machine (for expo client) and the frontend (for expo
server).

The following command should be executed on your machine as well as on the
frontend:

    $ echo "---
    rmi_protocol: soap
    port: 15789" > ~/.expctrl_server

Now execute on your local machine (specifying your Grid5000 login and
password):

    $ mkdir ~/.restfully
    $ echo "
    username: USER_NAME
    password: GRID5000PASSWORD
    base_uri: https://api.grid5000.fr/2.0/grid5000
    " > ~/.restfully/api.grid5000.fr.yml
    $ chmod 0600 ~/.restfully/api.grid5000.fr.yml

And the last thing is to establish an SSH tunnel from your local machine:

    $ ssh -f USER_NAME@access.YOUR_FRONTEND.grid5000.fr -L 15789:frontend:15789 -N

specifying your USER_NAME and YOUR_FRONTEND where you will launch expo
server.

Now you run expo server on the frontend
  
    $ your_path/expo_improved/bin/expctrl_server.rb

And start the experiment on your local machine:

    $ your_path/expo_improved/bin/expo.rb path_to_your_test_file

