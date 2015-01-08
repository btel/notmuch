#!/usr/bin/env ruby
# coding: utf-8
# Copyright 2010, 2011, 2012 Ali Polatel <alip@exherbo.org>
# Distributed under the terms of the GNU General Public License v3

require 'mkmf'

dir = '/usr/local/Cellar/notmuch/0.18.1/lib/' 

# includes
$INCFLAGS = "-I#{$INCFLAGS} -I/usr/local/Cellar/ruby/2.2.0/include/ruby-2.2.0/x86_64-darwin14/"

# make sure there are no undefined symbols
$LDFLAGS += ''

def have_local_library(lib, path, func, headers = nil)
  checking_for checking_message(func, lib) do
    lib = File.join(path, lib)
    if try_func(func, lib, headers)
      $LOCAL_LIBS += lib
    end
  end
end

if not have_local_library('libnotmuch.dylib', dir, 'notmuch_database_create', 'notmuch.h')
  exit 1
end

# Create Makefile
dir_config('notmuch')
create_makefile('notmuch')
