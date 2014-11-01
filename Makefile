app:
	rerun --pattern '{*.rb,config.ru}' -- rackup

coffee:
	coffee -o public/ -cw src/

sass:
	sass --watch src/:public/
