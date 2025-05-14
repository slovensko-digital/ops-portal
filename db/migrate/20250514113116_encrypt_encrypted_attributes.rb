class EncryptEncryptedAttributes < ActiveRecord::Migration[8.0]
  def up
    Client.find_each do |client|
      client.encrypt
    end

    Connector::Tenant.find_each do |tenant|
      tenant.encrypt
    end
  end

  def down
    Client.find_each do |client|
      client.decrypt
    end

    Connector::Tenant.find_each do |tenant|
      tenant.decrypt
    end
  end
end
