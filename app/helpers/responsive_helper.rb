module ResponsiveHelper
  def responsive_image_tag(attachment, srcset:, **options)
    return nil unless attachment.representable?

    srcset2 = srcset.map.with_index(1) do |variant, idx|
      "#{url_for(attachment.variant(variant))} #{idx}x"
    end.join(", ")
    image_tag attachment.variant(srcset.first), srcset: srcset2, **options
  end
end
