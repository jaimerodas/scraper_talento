# frozen_string_literal: true

require 'bundler/setup'
require 'capybara/poltergeist'
require 'csv'
require 'yaml'
require 'progress_bar'

require_relative 'scraper_talento/functions'
require_relative 'scraper_talento/candidate_processor'
require_relative 'scraper_talento/runner'
