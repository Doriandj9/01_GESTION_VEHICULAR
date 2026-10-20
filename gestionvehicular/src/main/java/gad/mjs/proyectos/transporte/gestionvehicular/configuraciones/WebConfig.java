package gad.mjs.proyectos.transporte.gestionvehicular.configuraciones;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ApiVersionConfigurer;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Arrays;


@Slf4j
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${application.hosts.admit}")
    private String[] hostsPermit;

    @Override
    public void configureApiVersioning(ApiVersionConfigurer configurer) {
        configurer
                .usePathSegment(1)
                .setVersionRequired(false)
                .addSupportedVersions("v1.0","v2.0","v1","v2")
                .setDefaultVersion("v1.0")
                .setVersionParser(new ApiVersionParser());
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        log.info("addCorsMappings hostsPermit={}", Arrays.stream(hostsPermit).toList());
        registry.addMapping("/**")
                .allowedOrigins(hostsPermit)
                .allowedMethods("*")
                .allowedHeaders("*");
    }
}
