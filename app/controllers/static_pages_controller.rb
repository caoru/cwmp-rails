class StaticPagesController < ApplicationController
  def home
  end

  def settings
    @models = TRXML.xmls;
  end

  def download
  end

  def upload
  end
end

