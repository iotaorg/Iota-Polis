-- Deploy iota:0076-new-download to pg
-- requires: 0075-indicadores-campos

BEGIN;


DROP VIEW download_data;

CREATE OR REPLACE VIEW download_data AS
 SELECT m.city_id,
    c.name AS city_name,
    e.name AS axis_name,
    m.indicator_id,
    i.name AS indicator_name,
    i.formula_human,
    i.explanation as formula_explanation,
    i.formula,
    i.observations as nossa_leitura,

    i.period,

    m.valid_from,
    m.value,
    a.goal AS user_goal,


    m.institute_id,
    m.user_id,
    m.region_id,
    m.sources,
    r.name AS region_name,
    m.updated_at,
    m.values_used
   FROM indicator_value m
     JOIN city c ON m.city_id = c.id
     JOIN indicator i ON i.id = m.indicator_id
     LEFT JOIN axis e ON e.id = i.axis_id
     LEFT JOIN indicator_variations iv ON
        CASE
            WHEN m.variation_name = ''::text THEN false
            ELSE iv.name = m.variation_name AND iv.indicator_id = m.indicator_id AND (iv.user_id = m.user_id OR iv.user_id = i.user_id)
        END
     LEFT JOIN user_indicator a ON a.user_id = m.user_id AND a.valid_from = m.valid_from AND a.indicator_id = m.indicator_id

     LEFT JOIN region r ON r.id = m.region_id;


COMMIT;
