@echo off
echo ======================================
echo Compilando e simulando Cache com Mapeamento Direto
echo ======================================
ghdl -a cache_direct_mapped.vhd
ghdl -a tb_cache_direct_mapped.vhd
ghdl -e tb_cache_direct_mapped
ghdl -r tb_cache_direct_mapped --vcd=direct_mapped_test.vcd --stop-time=3000ns > direct_mapped_results.txt

echo.
echo ======================================
echo Compilando e simulando Cache com Mapeamento Associativo de 4 vias
echo ======================================
ghdl -a cache_4way_associative.vhd
ghdl -a tb_cache_4way_associative.vhd
ghdl -e tb_cache_4way_associative
ghdl -r tb_cache_4way_associative --vcd=associative_test.vcd --stop-time=3000ns > associative_results.txt

echo.
echo ======================================
echo Simulações concluídas!
echo ======================================
echo Resultados salvos em:
echo - direct_mapped_results.txt
echo - associative_results.txt
echo.
echo Formas de onda salvas em:
echo - direct_mapped_test.vcd
echo - associative_test.vcd
echo.
echo Para visualizar as formas de onda, use:
echo gtkwave direct_mapped_test.vcd
echo gtkwave associative_test.vcd
echo ======================================

pause