# frozen_string_literal: true

require 'bundler/setup'
require 'capybara/poltergeist'
require 'csv'
require 'yaml'
require 'progress_bar'
require 'active_support/inflector'

require_relative 'scraper_talento/functions'
require_relative 'scraper_talento/file_functions'
require_relative 'scraper_talento/resume_gatherer'
require_relative 'scraper_talento/candidate_processor'
require_relative 'scraper_talento/runner'
