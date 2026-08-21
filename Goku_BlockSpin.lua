-- SCRIPT ACTIVO PARA BLOCK SPIN (PROTEGIDO)
task.spawn(function()
    task.wait(2) -- Espera de seguridad
    local exito, resultado = pcall(function()
        -- Enlace oficial activo de Hermanos Dev
        return game:HttpGet("https://raw.githubusercontent.com/hermanos-dev/hermanos-hub/refs/heads/main/BlockSpin/blockspin-farm.lua")
    end)
    
    if exito and resultado then
        local cargarScript = loadstring(resultado)
        if cargarScript then
            pcall(cargarScript)
        end
    end
end)
