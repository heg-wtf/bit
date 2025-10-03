build:
	zvc build
	echo "bit.heg.wtf" > ./docs/CNAME

init:
	@read -p "Enter date (YYMMDD): " date; \
	mkdir -p ./contents/$$date; \
	year="20$${date:0:2}"; \
	month="$${date:2:2}"; \
	day="$${date:4:2}"; \
	pub_date="$$year-$$month-$$day"; \
	echo "---" > ./contents/$$date/$$date.md; \
	echo "title: '$$date'" >> ./contents/$$date/$$date.md; \
	echo "author: 'heg'" >> ./contents/$$date/$$date.md; \
	echo "pub_date: '$$pub_date'" >> ./contents/$$date/$$date.md; \
	echo "description: ''" >> ./contents/$$date/$$date.md; \
	echo "featured_image: ''" >> ./contents/$$date/$$date.md; \
	echo "tags: ['드라이버펍', 'heg']" >> ./contents/$$date/$$date.md; \
	echo "---" >> ./contents/$$date/$$date.md; \
	echo "" >> ./contents/$$date/$$date.md; \
	echo "Created ./contents/$$date/$$date.md"