step_size=1

1.upto(100) do |i|
        delete_probability = i.to_f / 100 
        if i % step_size == 0 then
                puts "Delete probability: #{delete_probability}"
                system "prism -g \"[experiments], tx_split(#{delete_probability})\""
        end
end
