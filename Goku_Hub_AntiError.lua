-- CÓDIGO INMUNE A ERRORES
task.wait(2) -- Da tiempo a que el juego cargue por completo

local exito, resultado = pcall(function()
    -- Se corrigió la dirección web repetida de GitHub
    return game:HttpGet("https://githubusercontent.com")
end)

if exito and resultado then
    local cargarScript, errorDeCompilacion = loadstring(resultado)
    if cargarScript then
        pcall(cargarScript) -- Ejecuta el menú sin riesgo de caídas
    end
end
