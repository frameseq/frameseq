step_size=1
score_groups=100
split_at_terminus=false

1.upto(100) do |i|
        delete_probability = i.to_f / 100 
        if i % step_size == 0 then
                puts "Delete probability: #{delete_probability}"
                system "prism -g \"[experiments], genemark_filter(#{delete_probability},#{score_groups},#{split_at_terminus ? 'true' : 'false'})\""
        end
end
