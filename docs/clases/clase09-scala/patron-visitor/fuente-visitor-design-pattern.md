# Visitor Design Pattern

> Conversión fiel a Markdown de TAdP - Visitor Design Pattern.pdf (6 páginas).

**Notas de conversión**

- El PDF es la impresión desde navegador de la página web https://sourcemaking.com/design_patterns/visitor. Cada página repite el encabezado de impresión (`24/10/26, 10:47 a.m.` — `Visitor Design Pattern`) y el pie (`https://sourcemaking.com/design_patterns/visitor` — `N/6`); se transcriben una sola vez, abajo, en lugar de repetirse en cada corte de página.
- Errores del original transcriptos tal cual: en *Discussion* dice "that is represents" (se lee como "that it represents"); en la nota de código del segundo diagrama se declara el arreglo `operations` pero se usa `operation[0]`.
- Inconsistencias del original en el primer diagrama: `VisitorOne` lleva el estereotipo «interface» aunque es una subclase concreta de `Visitor` según el texto; solo `ElementOne` muestra el método `accept()` (`ElementTwo` aparece vacío). En el segundo diagrama, solo `FirstOne` muestra `firstDispatch()` y solo `SecondThree` muestra los `secondDispatch()` redefinidos. Se transcribe lo que figura, sin completar.
- Los hipervínculos se extrajeron de las anotaciones del PDF y van inline. Los íconos del encabezado del sitio (logo, sobre, figura) no tienen texto; su destino se indica en la descripción.

---

**[Encabezado del sitio]** Barra superior verde turquesa con el logo de SourceMaking (ilustración de un monstruo verde con la leyenda "SOURCE MAKING"), enlazado a https://sourcemaking.com/. A la derecha, tres íconos: un sobre (enlace a https://feedback.sourcemaking.com/?lang=en&show_feedback_form_private=true), una figura corriendo hacia una puerta (enlace a https://sourcemaking.com/login) y un menú de tres líneas (sin enlace).

[🏠](https://sourcemaking.com/) / [Design Patterns](https://sourcemaking.com/design_patterns) / [Behavioral patterns](https://sourcemaking.com/design_patterns/behavioral_patterns)

# Visitor Design Pattern

## Intent

- Represent an operation to be performed on the elements of an object structure. Visitor lets you define a new operation without changing the classes of the elements on which it operates.
- The classic technique for recovering lost type information.
- Do the right thing based on the type of two objects.
- Double dispatch

## Problem

Many distinct and unrelated operations need to be performed on node objects in a heterogeneous aggregate structure. You want to avoid "polluting" the node classes with these operations. And, you don't want to have to query the type of each node and cast the pointer to the correct type before performing the desired operation.

## Discussion

Visitor's primary purpose is to abstract functionality that can be applied to an aggregate hierarchy of "element" objects. The approach encourages designing lightweight Element classes - because processing functionality is removed from their list of responsibilities. New functionality can easily be added to the original inheritance hierarchy by creating a new Visitor subclass.

Visitor implements "double dispatch". OO messages routinely manifest "single dispatch"- the operation that is executed depends on: the name of the request, and the type of the receiver. In "double dispatch", the operation executed depends on: the name of the request, and the type of TWO receivers (the type of the Visitor and the type of the element it visits).

The implementation proceeds as follows. Create a Visitor class hierarchy that defines a pure virtual `visit()` method in the abstract base class for each concrete derived class in the aggregate node hierarchy. Each `visit()` method accepts a single argument - a pointer or reference to an original Element derived class.

Each operation to be supported is modelled with a concrete derived class of the Visitor hierarchy. The `visit()` methods declared in the Visitor base class are now defined in each derived subclass by allocating the "type query and cast" code in the original implementation to the appropriate overloaded `visit()` method.

Add a single pure virtual `accept()` method to the base class of the Element hierarchy. `accept()` is defined to receive a single argument - a pointer or reference to the abstract base class of the Visitor hierarchy.

Each concrete derived class of the Element hierarchy implements the `accept()` method by simply calling the `visit()` method on the concrete derived instance of the Visitor hierarchy that it was passed, passing its "this" pointer as the sole argument.

Everything for "elements" and "visitors" is now set-up. When the client needs an operation to be performed, (s)he creates an instance of the Visitor object, calls the `accept()` method on each Element object, and passes the Visitor object.

The `accept()` method causes flow of control to find the correct Element subclass. Then when the `visit()` method is invoked, flow of control is vectored to the correct Visitor subclass. `accept()` dispatch plus `visit()` dispatch equals double dispatch.

The Visitor pattern makes adding new operations (or utilities) easy - simply add a new Visitor derived class. But, if the subclasses in the aggregate node hierarchy are not stable, keeping the Visitor subclasses in sync requires a prohibitive amount of effort.

An acknowledged objection to the Visitor pattern is that is represents a regression to functional decomposition - separate the algorithms from the data structures. While this is a legitimate interpretation, perhaps a better perspective/rationale is the goal of promoting non-traditional behavior to full object status.

## Structure

The Element hierarchy is instrumented with a "universal method adapter". The implementation of `accept()` in each Element derived class is always the same. But – it cannot be moved to the Element base class and inherited by all derived classes because a reference to `this` in the Element class always maps to the base type Element.

```
      +----------+
      |  Client  |
      +----------+
           |
           v
  +------------------+                       +-------------------------------+
  |   «interface»    |                       |          «interface»          |
  |     Element      |                       |            Visitor            |
  +------------------+                       +-------------------------------+
  |                  |                       | +visit(in e : ElementOne)     |
  +------------------+                       | +visit(in e : ElementTwo)     |
           △                                 +-------------------------------+
           |                                                 △
     +-----+--------------+                    +-------------+-------------+
     |                    |                    |                           |
+----------------------+ +------------+  +------------------------------+ +------------+
|      ElementOne      | | ElementTwo |  |    «interface» VisitorOne    | | VisitorTwo |
+----------------------+ +------------+  +------------------------------+ +------------+
|                      | |            |  | +visit(in e : ElementOne)    |
+----------------------+ +------------+  | +visit(in e : ElementTwo)    |
| +accept(in v:Visitor)| |            |  +------------------------------+
+----------------------+ +------------+                 :
           :                                            :
  +------------------+             +------------------------------------------+
  | v.visit(this);   |             | The concrete types of the                |
  +------------------+             | Element and Visitor objects have         |
                                   | been "recovered". Perform the work       |
                                   | appropriate for their pair of types.     |
                                   +------------------------------------------+
```

*Descripción del diagrama:* diagrama de clases UML. `Client` tiene una flecha de asociación hacia la interfaz `Element` («interface», sin métodos visibles). `ElementOne` y `ElementTwo` heredan/implementan `Element` (triángulo hueco). `ElementOne` declara `+accept(in v : Visitor)`, con una nota unida por línea punteada que dice `v.visit(this);`; `ElementTwo` aparece sin métodos. A la derecha, la interfaz `Visitor` («interface») declara `+visit(in e : ElementOne)` y `+visit(in e : ElementTwo)` (en cursiva). `VisitorOne` (marcada «interface») y `VisitorTwo` heredan de `Visitor`; `VisitorOne` repite los dos métodos `visit`, `VisitorTwo` aparece solo con su nombre. Una nota unida a `VisitorOne` dice: "The concrete types of the Element and Visitor objects have been "recovered". Perform the work appropriate for their pair of types." No hay flecha dibujada entre `Client` y `Visitor`.

When the polymorphic `firstDispatch()` method is called on an abstract `First` object, the concrete type of that object is "recovered". When the polymorphic `secondDispatch()` method is called on an abstract `Second` object, its concrete type is "recovered". The application functionality appropriate for this pair of types can now be exercised.

```
 +------------------------------------------------------+
 | First[] elements = {new FirstOne(), ...};            |
 | Second[] operations = {new SecondThree(), ...}       |
 | for each element                                     |
 |   elements[i].firstDispatch(operation[0]);           |
 +------------------------------------------------------+
            :
      +-----------+                              +----------------------------------+
      |  Client   |----------------------------->|              First               |
      +-----------+                              +----------------------------------+
      |           |                              | +firstDispatch(in s : Second)    |
      +-----------+                              +----------------------------------+
            |                                                    △
            v                               +--------------------+------------------+
 +-------------------------------------+    |                    |                  |
 |               Second                |  +-------------------------------+ +----------+ +------------+
 +-------------------------------------+  |           FirstOne            | | FirstTwo | | FirstThree |
 | +secondDispatch(in f : FirstOne)    |  +-------------------------------+ +----------+ +------------+
 | +secondDispatch(in f : FirstTwo)    |  | +firstDispatch(in s : Second) | |          | |            |
 | +secondDispatch(in f : FirstThree)  |  +-------------------------------+ +----------+ +------------+
 +-------------------------------------+
                   △
     +-------------+-------------------+
     |             |                   |
+-----------+ +-----------+ +-------------------------------------+
| SecondOne | | SecondTwo | |             SecondThree             |      +-----------------------------+
+-----------+ +-----------+ +-------------------------------------+      | Do the right thing based on |
|           | |           | | +secondDispatch(in f : FirstOne)    |......| the type of two objects:    |
+-----------+ +-----------+ | +secondDispatch(in f : FirstTwo)    |      | FirstOne and SecondThree    |
                            | +secondDispatch(in f : FirstThree)  |      +-----------------------------+
                            +-------------------------------------+
```

*Descripción del diagrama:* diagrama de clases UML genérico de double dispatch. Una nota con pseudocódigo está unida a `Client` por línea punteada: `First[] elements = {new FirstOne(), ...};` / `Second[] operations = {new SecondThree(), ...}` / `for each element` / `elements[i].firstDispatch(operation[0]);`. `Client` tiene una flecha de asociación hacia `First` y otra hacia `Second`. `First` declara `+firstDispatch(in s : Second)`; de ella heredan `FirstOne` (que declara `+firstDispatch(in s : Second)`), `FirstTwo` y `FirstThree` (estas dos sin métodos visibles). `Second` declara `+secondDispatch(in f : FirstOne)`, `+secondDispatch(in f : FirstTwo)` y `+secondDispatch(in f : FirstThree)`; de ella heredan `SecondOne` y `SecondTwo` (sin métodos visibles) y `SecondThree`, que redefine los tres `secondDispatch`. Una nota unida a `SecondThree` dice: "Do the right thing based on the type of two objects: FirstOne and SecondThree".

## Example

The Visitor pattern represents an operation to be performed on the elements of an object structure without changing the classes on which it operates. This pattern can be observed in the operation of a taxi company. When a person calls a taxi company (accepting a visitor), the company dispatches a cab to the customer. Upon entering the taxi the customer, or Visitor, is no longer in control of his or her own transportation, the taxi (driver) is.

```
  Cab company dispatcher        Customer                    Taxi
  Object structure is           Concrete element of         Visitor
  list of Customers             Customers list
          |                          |                         |
          |  SendCab()               |                         |
          |------------------------->|                         |
          |  (AcceptAVisitor)        |                         |
          |                          |  Enter(Cab)             |
          |                          |------------------------>|
          |                          |  (VisitCustomer)        |
          |                          |                         |
          |                          |  Transport(Customer)    |
          |                          |<------------------------|
          |                          |                         |
```

*Descripción del diagrama:* ilustración con tres personajes y un diagrama de secuencia debajo. Arriba, de izquierda a derecha: una operadora con auriculares frente a una computadora, rotulada **Cab company dispatcher** ("Object structure is list of Customers"); un hombre de traje hablando por celular, rotulado **Customer** ("Concrete element of Customers list"); y un taxi amarillo, rotulado **Taxi** ("Visitor"). Debajo, tres líneas de vida verticales. Mensajes, en orden: `SendCab()` del dispatcher al Customer, con la aclaración `(AcceptAVisitor)`; `Enter(Cab)` del Customer al Taxi, con la aclaración `(VisitCustomer)`; `Transport(Customer)` del Taxi al Customer.

## Check list

1. Confirm that the current hierarchy (known as the Element hierarchy) will be fairly stable and that the public interface of these classes is sufficient for the access the Visitor classes will require. If these conditions are not met, then the Visitor pattern is not a good match.
2. Create a Visitor base class with a `visit(ElementXxx)` method for each Element derived type.
3. Add an `accept(Visitor)` method to the Element hierarchy. The implementation in each Element derived class is always the same – `accept( Visitor v ) { v.visit( this ); }`. Because of cyclic dependencies, the declaration of the Element and Visitor classes will need to be interleaved.
4. The Element hierarchy is coupled only to the Visitor base class, but the Visitor hierarchy is coupled to each Element derived class. If the stability of the Element hierarchy is low, and the stability of the Visitor hierarchy is high; consider swapping the 'roles' of the two hierarchies.
5. Create a Visitor derived class for each "operation" to be performed on Element objects. `visit()` implementations will rely on the Element's public interface.
6. The client creates Visitor objects and passes each to Element objects by calling `accept()`.

## Rules of thumb

- The abstract syntax tree of Interpreter is a Composite (therefore Iterator and Visitor are also applicable).
- Iterator can traverse a Composite. Visitor can apply an operation over a Composite.
- The Visitor pattern is like a more powerful Command pattern because the visitor may initiate whatever is appropriate for the kind of object it encounters.
- The Visitor pattern is the classic technique for recovering lost type information without resorting to dynamic casts.

## Notes

The November 2000 issue of *JavaPro* has an article by James Cooper (author of a Java companion to the GoF) on the Visitor design pattern. He suggests it "turns the tables on our object-oriented model and creates an external class to act on data in other classes ... while this may seem unclean ... there are good reasons for doing it."

His primary example. Suppose you have a hierarchy of Employee-Engineer-Boss. They all enjoy a normal vacation day accrual policy, but, Bosses also participate in a "bonus" vacation day program. As a result, the interface of class Boss is different than that of class Engineer. We cannot polymorphically traverse a Composite-like organization and compute a total of the organization's remaining vacation days."The Visitor becomes more useful when there are several classes with different interfaces and we want to encapsulate how we get data from these classes."

His benefits for Visitor include:

- Add functions to class libraries for which you either do not have the source or cannot change the source
- Obtain data from a disparate collection of unrelated classes and use it to present the results of a global calculation to the user program
- Gather related operations into a single class rather than force you to change or derive classes to add these operations
- Collaborate with the Composite pattern

Visitor is not good for the situation where "visited" classes are not stable. Every time a new Composite hierarchy derived class is added, every Visitor derived class must be amended.

## Support our free website and own the eBook!

- 22 design patterns and 8 principles explained in depth
- 406 well-structured, easy to read, jargon-free pages
- 228 clear and helpful illustrations and diagrams
- An archive with code examples in 4 languages
- All devices supported: EPUB/MOBI/PDF formats

[📄 Learn more...](https://sourcemaking.com/design-patterns-ebook)

*(A la derecha, imagen de la tapa del libro "Dive Into DESIGN PATTERNS", de Alexander Shvets: fondo azul oscuro con un hexágono concéntrico de líneas en rosa y celeste. La imagen enlaza a https://sourcemaking.com/design-patterns-ebook.)*

## Code examples

| Lenguaje | | | | |
|---|---|---|---|---|
| **Java** | [Visitor in Java](https://sourcemaking.com/design_patterns/visitor/java/1) | [Visitor in Java: Double dispatch (within a single hierarchy)](https://sourcemaking.com/design_patterns/visitor/java/2) | [Visitor in Java](https://sourcemaking.com/design_patterns/visitor/java/3) | [Visitor in Java](https://sourcemaking.com/design_patterns/visitor/java/4) |
| **C++** | [Visitor in C++: Before and after](https://sourcemaking.com/design_patterns/visitor/cpp/1) | [Visitor in C++](https://sourcemaking.com/design_patterns/visitor/cpp/2) | [Visitor in C++: Recovering lost type information](https://sourcemaking.com/design_patterns/visitor/cpp/3) | |
| **PHP** | [Visitor in PHP](https://sourcemaking.com/design_patterns/visitor/php) | | | |
| **Delphi** | [Visitor in Delphi](https://sourcemaking.com/design_patterns/visitor/delphi) | | | |
| **Python** | [Visitor in Python](https://sourcemaking.com/design_patterns/visitor/python/1) | | | |

**RETURN**

[← Template Method](https://sourcemaking.com/design_patterns/template_method)

---

**[Pie del sitio]**

[Design Patterns](https://sourcemaking.com/design_patterns) · [AntiPatterns](https://sourcemaking.com/antipatterns) · [Refactoring](https://sourcemaking.com/refactoring) · [UML](https://sourcemaking.com/uml)

[My account](https://sourcemaking.com/home) · [Forum](https://feedback.sourcemaking.com/?lang=en) · [Contact us](https://feedback.sourcemaking.com/?lang=en&show_feedback_form_private=true) · [About us](https://sourcemaking.com/about-us)

© 2007-2026 [SourceMaking.com](https://sourcemaking.com/)
All rights reserved.

[Terms](https://sourcemaking.com/terms) / [Privacy policy](https://sourcemaking.com/privacy-policy)

---

**[Encabezado y pie de impresión, repetidos en las 6 páginas]** `24/10/26, 10:47 a.m.` · `Visitor Design Pattern` · `https://sourcemaking.com/design_patterns/visitor` · `1/6` … `6/6`

---

**FIN DEL ARCHIVO FUENTE — Visitor Design Pattern**
