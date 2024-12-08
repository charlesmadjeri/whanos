FROM alpine:latest

RUN apk add --no-cache bash
SHELL ["/bin/bash", "-c"]

WORKDIR /app

RUN echo '<xyXYvp01<>110vv5_v#`0+1:_v#+!-"g"\<v"<":::<>1v#p03-1_>! g20gp00g1+0v25p\n\
v2g02 < p0 20p<+vp020p01-10$_:"p"-!^>>-!\ v^ <>0p20pv|!*-";"\+1::~p0<\n\
v2-10<^v# ^#<  <<$<       < ^+!-"_"\+!-"?"<>#^_1v>vp<:^00 _$20g1+20p^\n\
v21p010>#<40g20v> %:40p5+g:92p:75*1--00g!\#^_00p$v>4v>91+-^\n\
<3+g01g 03p04+g<^\++g04g02:*54p03:%\++g03g01:"P"<<p0<' > /usr/local/bin/befunge-interpreter && \
    chmod +x /usr/local/bin/befunge-interpreter

RUN echo '#!/bin/bash\n\
cat $1 | /usr/local/bin/befunge-interpreter' > /usr/local/bin/bef && \
    chmod +x /usr/local/bin/bef

COPY . .
RUN rm -rf Dockerfile* .git*

CMD ["/usr/local/bin/bef", "./app/main.bf"] 