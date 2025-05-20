class ReplaceActiveStorageBlobJfifExtension < ActiveRecord::Migration[8.0]
  def up
    ActiveStorage::Blob.where("filename ILIKE ?", "%.jfif").find_each do |blob|
      blob.update!(filename: blob.filename.to_s.gsub(/\.jfif/i, '.jpeg'))
    end
  end
end
